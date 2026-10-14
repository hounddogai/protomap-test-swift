import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol override is in its life cycle.
    enum CareProtocolOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a care protocol override and its current status.
    final class CareProtocolOverride {
        var code: String
        var label: String
        var windowDays: Int
        var limit: Int
        var specialty: String
        var minimum: Double
        var ceiling: Double
        var rate: Double
        var ownerID: String
        var status: CareProtocolOverrideStatus

        init(code: String, label: String, windowDays: Int, limit: Int, specialty: String, minimum: Double, ceiling: Double, rate: Double, ownerID: String, status: CareProtocolOverrideStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.limit = limit
            self.specialty = specialty
            self.minimum = minimum
            self.ceiling = ceiling
            self.rate = rate
            self.ownerID = ownerID
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

        func canMoveTo(_ next: CareProtocolOverrideStatus) -> Bool {
            switch status {
            case .draft:
                return next == CareProtocolOverrideStatus.suspended
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CareProtocolOverrideStatus.suspended || next == CareProtocolOverrideStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: CareProtocolOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedVolume() -> Double {
            return ((minimum - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolOverride {
            return CareProtocolOverride(
                code: code,
                label: label,
                windowDays: windowDays,
                limit: limit,
                specialty: specialty,
                minimum: minimum,
                ceiling: ceiling,
                rate: rate,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care protocol override in status draft.
    static func newCareProtocolOverride(_ code: String, label: String) -> CareProtocolOverride {
        return CareProtocolOverride(
            code: code,
            label: label,
            windowDays: 0,
            limit: 0,
            specialty: "",
            minimum: 0.0,
            ceiling: 0.0,
            rate: 0.0,
            ownerID: "",
            status: CareProtocolOverrideStatus.draft
        )
    }
}
