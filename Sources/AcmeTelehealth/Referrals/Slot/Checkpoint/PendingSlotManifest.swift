import AcmePlatform
import Foundation

extension Referrals {
    /// Where a pending slot manifest is in its life cycle.
    enum PendingSlotManifestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A pending slot manifest as the slot team keeps it.
    final class PendingSlotManifest {
        var code: String
        var label: String
        var retries: Int
        var startsAt: Int
        var visible: Bool
        var score: Double
        var unit: String
        var status: PendingSlotManifestStatus

        init(code: String, label: String, retries: Int, startsAt: Int, visible: Bool, score: Double, unit: String, status: PendingSlotManifestStatus) {
            self.code = code
            self.label = label
            self.retries = retries
            self.startsAt = startsAt
            self.visible = visible
            self.score = score
            self.unit = unit
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

        func canMoveTo(_ next: PendingSlotManifestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
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

        func moveTo(_ next: PendingSlotManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending slot manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedExposure() -> Double {
            return (Double(startsAt) * score * 100).rounded() / 100
        }

        func copyValue() -> PendingSlotManifest {
            return PendingSlotManifest(
                code: code,
                label: label,
                retries: retries,
                startsAt: startsAt,
                visible: visible,
                score: score,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending slot manifest in status idle.
    static func newPendingSlotManifest(_ code: String, label: String) -> PendingSlotManifest {
        return PendingSlotManifest(
            code: code,
            label: label,
            retries: 0,
            startsAt: 0,
            visible: false,
            score: 0.0,
            unit: "",
            status: PendingSlotManifestStatus.idle
        )
    }
}
