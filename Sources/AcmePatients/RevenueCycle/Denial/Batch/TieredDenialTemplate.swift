import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered denial template is in its life cycle.
    enum TieredDenialTemplateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A tiered denial template as the denial team keeps it.
    final class TieredDenialTemplate {
        var code: String
        var title: String
        var acuity: Int
        var margin: Double
        var dosageMg: Double
        var status: TieredDenialTemplateStatus

        init(code: String, title: String, acuity: Int, margin: Double, dosageMg: Double, status: TieredDenialTemplateStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.margin = margin
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredDenialTemplateStatus) -> Bool {
            switch status {
            case .idle:
                return next == TieredDenialTemplateStatus.warming || next == TieredDenialTemplateStatus.ready
            case .warming:
                return next == TieredDenialTemplateStatus.ready || next == TieredDenialTemplateStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: TieredDenialTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered denial template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedExposure() -> Double {
            return ((margin - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> TieredDenialTemplate {
            return TieredDenialTemplate(
                code: code,
                title: title,
                acuity: acuity,
                margin: margin,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered denial template in status idle.
    static func newTieredDenialTemplate(_ code: String, title: String) -> TieredDenialTemplate {
        return TieredDenialTemplate(
            code: code,
            title: title,
            acuity: 0,
            margin: 0.0,
            dosageMg: 0.0,
            status: TieredDenialTemplateStatus.idle
        )
    }
}
