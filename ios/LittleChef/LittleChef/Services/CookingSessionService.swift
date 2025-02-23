import Foundation

enum CookingSessionError: Error {
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
}

class CookingSessionService {
    private let baseURL = "http://localhost:8000/cooking-sessions"
    
    func createSession(recipeId: UUID) async throws -> CookingSession {
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let createRequest = CreateSessionRequest(recipeId: recipeId, currentStep: 0)
        request.httpBody = try JSONEncoder().encode(createRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CookingSessionError.invalidResponse
            }
            
            return try JSONDecoder().decode(CookingSession.self, from: data)
        } catch let error as DecodingError {
            throw CookingSessionError.decodingError(error)
        } catch {
            throw CookingSessionError.networkError(error)
        }
    }
    
    func getStepActions(sessionId: UUID, stepNumber: Int) async throws -> [StepAction] {
        let url = URL(string: "\(baseURL)/\(sessionId.uuidString)/step_actions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let stepRequest = StepActionRequest(stepNumber: stepNumber)
        request.httpBody = try JSONEncoder().encode(stepRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CookingSessionError.invalidResponse
            }
            
            let stepResponse = try JSONDecoder().decode(StepActionResponse.self, from: data)
            return stepResponse.actions
        } catch let error as DecodingError {
            throw CookingSessionError.decodingError(error)
        } catch {
            throw CookingSessionError.networkError(error)
        }
    }
    
    func sendMessage(sessionId: UUID, message: String) async throws -> ChatResponse {
        let url = URL(string: "\(baseURL)/\(sessionId.uuidString)/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let chatRequest = ChatRequest(message: message)
        request.httpBody = try JSONEncoder().encode(chatRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CookingSessionError.invalidResponse
            }
            
            return try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch let error as DecodingError {
            throw CookingSessionError.decodingError(error)
        } catch {
            throw CookingSessionError.networkError(error)
        }
    }
    
    func deleteSession(sessionId: UUID) async throws {
        let url = URL(string: "\(baseURL)/\(sessionId.uuidString)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw CookingSessionError.invalidResponse
            }
        } catch {
            throw CookingSessionError.networkError(error)
        }
    }
}