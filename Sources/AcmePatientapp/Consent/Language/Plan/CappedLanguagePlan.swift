import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped language plan is in its life cycle.
    enum CappedLanguagePlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A capped language plan as the language team keeps it.
    final class CappedLanguagePlan {
        var code: String
        var name: String
        var maximum: Double
        var phone: String
        var attributes: [String: String]
        var attempts: Int
        var reviewer: String
        var dosageMg: Double
        var unit: String
        var pinned: Bool
        var status: CappedLanguagePlanStatus

        init(code: String, name: String, maximum: Double, phone: String, attributes: [String: String], attempts: Int, reviewer: String, dosageMg: Double, unit: String, pinned: Bool, status: CappedLanguagePlanStatus) {
            self.code = code
            self.name = name
            self.maximum = maximum
            self.phone = phone
            self.attributes = attributes
            self.attempts = attempts
            self.reviewer = reviewer
            self.dosageMg = dosageMg
            self.unit = unit
            self.pinned = pinned
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

        func canMoveTo(_ next: CappedLanguagePlanStatus) -> Bool {
            switch status {
            case .new:
                return next == CappedLanguagePlanStatus.done || next == CappedLanguagePlanStatus.failed
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: CappedLanguagePlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped language plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("capped language plan") \(code)"
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

        func netValue() -> Double {
            return ((Double(attempts) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> CappedLanguagePlan {
            return CappedLanguagePlan(
                code: code,
                name: name,
                maximum: maximum,
                phone: phone,
                attributes: attributes,
                attempts: attempts,
                reviewer: reviewer,
                dosageMg: dosageMg,
                unit: unit,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a capped language plan in status new.
    static func newCappedLanguagePlan(_ code: String, name: String) -> CappedLanguagePlan {
        return CappedLanguagePlan(
            code: code,
            name: name,
            maximum: 0.0,
            phone: "",
            attributes: [:],
            attempts: 0,
            reviewer: "",
            dosageMg: 0.0,
            unit: "",
            pinned: false,
            status: CappedLanguagePlanStatus.new
        )
    }
}
