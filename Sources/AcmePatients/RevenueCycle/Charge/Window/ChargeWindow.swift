import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge window is in its life cycle.
    enum ChargeWindowStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One charge window, with what the planners need to act on it.
    final class ChargeWindow {
        var code: String
        var title: String
        var dosageMg: Double
        var label: String
        var revision: Int
        var source: String
        var approved: Bool
        var category: String
        var score: Double
        var visitMinutes: Int
        var status: ChargeWindowStatus

        init(code: String, title: String, dosageMg: Double, label: String, revision: Int, source: String, approved: Bool, category: String, score: Double, visitMinutes: Int, status: ChargeWindowStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.label = label
            self.revision = revision
            self.source = source
            self.approved = approved
            self.category = category
            self.score = score
            self.visitMinutes = visitMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ChargeWindowStatus) -> Bool {
            switch status {
            case .requested:
                return next == ChargeWindowStatus.granted || next == ChargeWindowStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ChargeWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("charge window") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(revision) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ChargeWindow {
            return ChargeWindow(
                code: code,
                title: title,
                dosageMg: dosageMg,
                label: label,
                revision: revision,
                source: source,
                approved: approved,
                category: category,
                score: score,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a charge window in status requested.
    static func newChargeWindow(_ code: String, title: String) -> ChargeWindow {
        return ChargeWindow(
            code: code,
            title: title,
            dosageMg: 0.0,
            label: "",
            revision: 0,
            source: "",
            approved: false,
            category: "",
            score: 0.0,
            visitMinutes: 0,
            status: ChargeWindowStatus.requested
        )
    }
}
