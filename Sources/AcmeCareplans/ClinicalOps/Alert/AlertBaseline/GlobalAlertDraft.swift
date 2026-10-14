import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global alert draft is in its life cycle.
    enum GlobalAlertDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A global alert draft. Its code is unique within a tenant.
    final class GlobalAlertDraft {
        var code: String
        var name: String
        var specialty: String
        var cost: Double
        var graceDays: Int
        var approved: Bool
        var ward: String
        var ceiling: Double
        var attributes: [String: String]
        var minimum: Double
        var weight: Double
        var status: GlobalAlertDraftStatus

        init(code: String, name: String, specialty: String, cost: Double, graceDays: Int, approved: Bool, ward: String, ceiling: Double, attributes: [String: String], minimum: Double, weight: Double, status: GlobalAlertDraftStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.cost = cost
            self.graceDays = graceDays
            self.approved = approved
            self.ward = ward
            self.ceiling = ceiling
            self.attributes = attributes
            self.minimum = minimum
            self.weight = weight
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

        func canMoveTo(_ next: GlobalAlertDraftStatus) -> Bool {
            switch status {
            case .new:
                return next == GlobalAlertDraftStatus.queued || next == GlobalAlertDraftStatus.failed
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == GlobalAlertDraftStatus.done
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

        func moveTo(_ next: GlobalAlertDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global alert draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("global alert draft") \(code)"
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

        func adjustedLoad() -> Double {
            return (Double(graceDays) * weight * 100).rounded() / 100
        }

        func copyValue() -> GlobalAlertDraft {
            return GlobalAlertDraft(
                code: code,
                name: name,
                specialty: specialty,
                cost: cost,
                graceDays: graceDays,
                approved: approved,
                ward: ward,
                ceiling: ceiling,
                attributes: attributes,
                minimum: minimum,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a global alert draft in status new.
    static func newGlobalAlertDraft(_ code: String, name: String) -> GlobalAlertDraft {
        return GlobalAlertDraft(
            code: code,
            name: name,
            specialty: "",
            cost: 0.0,
            graceDays: 0,
            approved: false,
            ward: "",
            ceiling: 0.0,
            attributes: [:],
            minimum: 0.0,
            weight: 0.0,
            status: GlobalAlertDraftStatus.new
        )
    }
}
