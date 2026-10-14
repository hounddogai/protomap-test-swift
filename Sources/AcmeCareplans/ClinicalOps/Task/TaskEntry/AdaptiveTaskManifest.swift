import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive task manifest is in its life cycle.
    enum AdaptiveTaskManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A adaptive task manifest as the task team keeps it.
    final class AdaptiveTaskManifest {
        var code: String
        var title: String
        var refills: Int
        var payer: String
        var floorValue: Double
        var status: AdaptiveTaskManifestStatus

        init(code: String, title: String, refills: Int, payer: String, floorValue: Double, status: AdaptiveTaskManifestStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.payer = payer
            self.floorValue = floorValue
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

        func canMoveTo(_ next: AdaptiveTaskManifestStatus) -> Bool {
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
                return next == AdaptiveTaskManifestStatus.suspended
            case .active:
                return next == AdaptiveTaskManifestStatus.suspended || next == AdaptiveTaskManifestStatus.closed
            case .suspended:
                return next == AdaptiveTaskManifestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveTaskManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive task manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netLoad() -> Double {
            return (Double(refills) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveTaskManifest {
            return AdaptiveTaskManifest(
                code: code,
                title: title,
                refills: refills,
                payer: payer,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive task manifest in status draft.
    static func newAdaptiveTaskManifest(_ code: String, title: String) -> AdaptiveTaskManifest {
        return AdaptiveTaskManifest(
            code: code,
            title: title,
            refills: 0,
            payer: "",
            floorValue: 0.0,
            status: AdaptiveTaskManifestStatus.draft
        )
    }
}
