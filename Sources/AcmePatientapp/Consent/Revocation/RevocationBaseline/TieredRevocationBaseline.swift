import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered revocation baseline is in its life cycle.
    enum TieredRevocationBaselineStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered revocation baseline as the revocation team keeps it.
    final class TieredRevocationBaseline {
        var code: String
        var name: String
        var contactEmail: String
        var label: String
        var copay: Double
        var status: TieredRevocationBaselineStatus

        init(code: String, name: String, contactEmail: String, label: String, copay: Double, status: TieredRevocationBaselineStatus) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.label = label
            self.copay = copay
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

        func canMoveTo(_ next: TieredRevocationBaselineStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
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

        func moveTo(_ next: TieredRevocationBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered revocation baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> TieredRevocationBaseline {
            return TieredRevocationBaseline(
                code: code,
                name: name,
                contactEmail: contactEmail,
                label: label,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a tiered revocation baseline in status new.
    static func newTieredRevocationBaseline(_ code: String, name: String) -> TieredRevocationBaseline {
        return TieredRevocationBaseline(
            code: code,
            name: name,
            contactEmail: "",
            label: "",
            copay: 0.0,
            status: TieredRevocationBaselineStatus.new
        )
    }
}
