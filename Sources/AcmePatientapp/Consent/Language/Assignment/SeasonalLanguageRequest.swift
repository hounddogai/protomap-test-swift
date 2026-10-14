import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal language request is in its life cycle.
    enum SeasonalLanguageRequestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a seasonal language request and its current status.
    final class SeasonalLanguageRequest {
        var code: String
        var name: String
        var attributes: [String: String]
        var expiresAt: Int
        var score: Double
        var allergy: String
        var capacity: Int
        var status: SeasonalLanguageRequestStatus

        init(code: String, name: String, attributes: [String: String], expiresAt: Int, score: Double, allergy: String, capacity: Int, status: SeasonalLanguageRequestStatus) {
            self.code = code
            self.name = name
            self.attributes = attributes
            self.expiresAt = expiresAt
            self.score = score
            self.allergy = allergy
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalLanguageRequestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SeasonalLanguageRequestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalLanguageRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal language request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netTotal() -> Double {
            return ((score - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalLanguageRequest {
            return SeasonalLanguageRequest(
                code: code,
                name: name,
                attributes: attributes,
                expiresAt: expiresAt,
                score: score,
                allergy: allergy,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal language request in status new.
    static func newSeasonalLanguageRequest(_ code: String, name: String) -> SeasonalLanguageRequest {
        return SeasonalLanguageRequest(
            code: code,
            name: name,
            attributes: [:],
            expiresAt: 0,
            score: 0.0,
            allergy: "",
            capacity: 0,
            status: SeasonalLanguageRequestStatus.new
        )
    }
}
