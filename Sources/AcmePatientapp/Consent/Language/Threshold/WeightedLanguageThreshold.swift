import AcmePlatform
import Foundation

extension Consent {
    /// Where a weighted language threshold is in its life cycle.
    enum WeightedLanguageThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A weighted language threshold as the language team keeps it.
    final class WeightedLanguageThreshold {
        var code: String
        var name: String
        var copay: Double
        var maximum: Double
        var threshold: Double
        var specialty: String
        var category: String
        var archived: Bool
        var endsAt: Int
        var visitMinutes: Int
        var status: WeightedLanguageThresholdStatus

        init(code: String, name: String, copay: Double, maximum: Double, threshold: Double, specialty: String, category: String, archived: Bool, endsAt: Int, visitMinutes: Int, status: WeightedLanguageThresholdStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.maximum = maximum
            self.threshold = threshold
            self.specialty = specialty
            self.category = category
            self.archived = archived
            self.endsAt = endsAt
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedLanguageThresholdStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WeightedLanguageThresholdStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedLanguageThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted language threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveExposure() -> Double {
            return ((copay - threshold) * 100).rounded() / 100
        }

        func copyValue() -> WeightedLanguageThreshold {
            return WeightedLanguageThreshold(
                code: code,
                name: name,
                copay: copay,
                maximum: maximum,
                threshold: threshold,
                specialty: specialty,
                category: category,
                archived: archived,
                endsAt: endsAt,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a weighted language threshold in status proposed.
    static func newWeightedLanguageThreshold(_ code: String, name: String) -> WeightedLanguageThreshold {
        return WeightedLanguageThreshold(
            code: code,
            name: name,
            copay: 0.0,
            maximum: 0.0,
            threshold: 0.0,
            specialty: "",
            category: "",
            archived: false,
            endsAt: 0,
            visitMinutes: 0,
            status: WeightedLanguageThresholdStatus.proposed
        )
    }
}
