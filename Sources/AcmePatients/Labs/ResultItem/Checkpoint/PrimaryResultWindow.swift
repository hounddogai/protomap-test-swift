import AcmePlatform
import Foundation

extension Labs {
    /// Where a primary result window is in its life cycle.
    enum PrimaryResultWindowStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A primary result window as the result team keeps it.
    final class PrimaryResultWindow {
        var code: String
        var label: String
        var source: String
        var diagnosisCode: String
        var active: Bool
        var visitMinutes: Int
        var startsAt: Int
        var status: PrimaryResultWindowStatus

        init(code: String, label: String, source: String, diagnosisCode: String, active: Bool, visitMinutes: Int, startsAt: Int, status: PrimaryResultWindowStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.diagnosisCode = diagnosisCode
            self.active = active
            self.visitMinutes = visitMinutes
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryResultWindowStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PrimaryResultWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary result window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netValue() -> Double {
            return (Double(visitMinutes) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryResultWindow {
            return PrimaryResultWindow(
                code: code,
                label: label,
                source: source,
                diagnosisCode: diagnosisCode,
                active: active,
                visitMinutes: visitMinutes,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a primary result window in status open.
    static func newPrimaryResultWindow(_ code: String, label: String) -> PrimaryResultWindow {
        return PrimaryResultWindow(
            code: code,
            label: label,
            source: "",
            diagnosisCode: "",
            active: false,
            visitMinutes: 0,
            startsAt: 0,
            status: PrimaryResultWindowStatus.`open`
        )
    }
}
