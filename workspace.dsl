workspace {
    name "Task Planner"
    !identifiers hierarchical

    model {
        // Пользователи
        manager = person "Менеджер" "Управляет целями и задачами"
        executor = person "Исполнитель" "Выполняет задачи и меняет их статус"
        admin = person "Администратор" "Управляет пользователями"

        // Система
        ss = softwareSystem "Task Planner" {
            // Контейнеры
            apiGateway = container "API Gateway" "Маршрутизация запросов" "Poco::Net::HTTPServer"
            userDb = container "User Database" "Хранение данных о пользователях" "PostgreSQL"
            goalsDb = container "Goals & Tasks Database" "Хранение данных о целях и задачах" "PostgreSQL"
            
            userService = container "User Service" "Управление пользователями (создание, поиск)" "C++ (Poco + libpqxx)" {
                -> userDb "CRUD" "libpqxx"
            }
            
            goalsService = container "Goals & Tasks Service" "Управление целями и задачами" "C++ (Poco + libpqxx)" {
                -> goalsDb "CRUD" "libpqxx"
            }
        }

        // Контексты использования
        manager -> ss "Для управления целями и задачами"
        manager -> ss.apiGateway "Отправить POST-запрос" "REST API"

        executor -> ss "Для просмотра целей и задач и изменения их статуса"
        executor -> ss.apiGateway "Отправить POST-запрос" "REST API"

        admin -> ss "Для просмотра пользователей и управления ими"
        admin -> ss.apiGateway "Отправить POST-запрос" "REST API"

        ss.apiGateway -> ss.goalsService "Назначить цели и задачи" "gRPC"
        ss.apiGateway -> ss.userService "Просмотреть и редактировать пользователей" "gRPC"
        
        ss.userService -> ss.goalsService "Назначение исполнителя" "gRPC"
    }

    views {
        systemContext ss {
            include *
            autolayout lr
        }

        container ss {
            include *
            autolayout lr
        }

        dynamic ss "Change_Task_Status" {
            autoLayout lr
            executor -> ss.apiGateway "POST" "REST API"
            ss.apiGateway -> ss.goalsService "Изменить статус задачи" "gRPC"
            ss.goalsService -> ss.goalsDb "Обновление статуса" "libpqxx"
        }
    }
}