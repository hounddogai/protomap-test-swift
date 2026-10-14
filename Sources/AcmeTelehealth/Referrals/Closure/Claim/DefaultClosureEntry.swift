import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default closure entry is in its life cycle.
    enum DefaultClosureEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A default closure entry. Its code is unique within a tenant.
    final class DefaultClosureEntry {
        var code: String
        var title: String
        var clinicianID: String
        var channel: String
        var maximum: Double
        var refills: Int
        var active: Bool
        var acuity: Int
        var ownerID: String
        var copay: Double
        var externalRef: String
        var status: DefaultClosureEntryStatus

        init(code: String, title: String, clinicianID: String, channel: String, maximum: Double, refills: Int, active: Bool, acuity: Int, ownerID: String, copay: Double, externalRef: String, status: DefaultClosureEntryStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.channel = channel
            self.maximum = maximum
            self.refills = refills
            self.active = active
            self.acuity = acuity
            self.ownerID = ownerID
            self.copay = copay
            self.externalRef = externalRef
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

        func canMoveTo(_ next: DefaultClosureEntryStatus) -> Bool {
            switch status {
            case .new:
                return next == DefaultClosureEntryStatus.done
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
                case .done:
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

        func moveTo(_ next: DefaultClosureEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default closure entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedExposure() -> Double {
            return (Double(acuity) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> DefaultClosureEntry {
            return DefaultClosureEntry(
                code: code,
                title: title,
                clinicianID: clinicianID,
                channel: channel,
                maximum: maximum,
                refills: refills,
                active: active,
                acuity: acuity,
                ownerID: ownerID,
                copay: copay,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a default closure entry in status new.
    static func newDefaultClosureEntry(_ code: String, title: String) -> DefaultClosureEntry {
        return DefaultClosureEntry(
            code: code,
            title: title,
            clinicianID: "",
            channel: "",
            maximum: 0.0,
            refills: 0,
            active: false,
            acuity: 0,
            ownerID: "",
            copay: 0.0,
            externalRef: "",
            status: DefaultClosureEntryStatus.new
        )
    }
}
