import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global task window is in its life cycle.
    enum GlobalTaskWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A global task window. Its code is unique within a tenant.
    final class GlobalTaskWindow {
        var code: String
        var name: String
        var unit: String
        var score: Double
        var contactEmail: String
        var specialty: String
        var startsAt: Int
        var status: GlobalTaskWindowStatus

        init(code: String, name: String, unit: String, score: Double, contactEmail: String, specialty: String, startsAt: Int, status: GlobalTaskWindowStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.score = score
            self.contactEmail = contactEmail
            self.specialty = specialty
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalTaskWindowStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == GlobalTaskWindowStatus.closed
            case .suspended:
                return next == GlobalTaskWindowStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalTaskWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global task window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("global task window") \(code)"
        }

        func adjustedValue() -> Double {
            return ((score + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalTaskWindow {
            return GlobalTaskWindow(
                code: code,
                name: name,
                unit: unit,
                score: score,
                contactEmail: contactEmail,
                specialty: specialty,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a global task window in status draft.
    static func newGlobalTaskWindow(_ code: String, name: String) -> GlobalTaskWindow {
        return GlobalTaskWindow(
            code: code,
            name: name,
            unit: "",
            score: 0.0,
            contactEmail: "",
            specialty: "",
            startsAt: 0,
            status: GlobalTaskWindowStatus.draft
        )
    }
}
