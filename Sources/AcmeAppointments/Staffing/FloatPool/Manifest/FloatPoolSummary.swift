import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool summary is in its life cycle.
    enum FloatPoolSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a float pool summary and its current status.
    final class FloatPoolSummary {
        var code: String
        var title: String
        var pinned: Bool
        var floorValue: Double
        var approved: Bool
        var discount: Double
        var checksum: String
        var label: String
        var notes: String
        var startsAt: Int
        var copay: Double
        var status: FloatPoolSummaryStatus

        init(code: String, title: String, pinned: Bool, floorValue: Double, approved: Bool, discount: Double, checksum: String, label: String, notes: String, startsAt: Int, copay: Double, status: FloatPoolSummaryStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.floorValue = floorValue
            self.approved = approved
            self.discount = discount
            self.checksum = checksum
            self.label = label
            self.notes = notes
            self.startsAt = startsAt
            self.copay = copay
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

        func canMoveTo(_ next: FloatPoolSummaryStatus) -> Bool {
            switch status {
            case .requested:
                return next == FloatPoolSummaryStatus.revoked
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

        func moveTo(_ next: FloatPoolSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func effectiveTotal() -> Double {
            return (discount * floorValue * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolSummary {
            return FloatPoolSummary(
                code: code,
                title: title,
                pinned: pinned,
                floorValue: floorValue,
                approved: approved,
                discount: discount,
                checksum: checksum,
                label: label,
                notes: notes,
                startsAt: startsAt,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a float pool summary in status requested.
    static func newFloatPoolSummary(_ code: String, title: String) -> FloatPoolSummary {
        return FloatPoolSummary(
            code: code,
            title: title,
            pinned: false,
            floorValue: 0.0,
            approved: false,
            discount: 0.0,
            checksum: "",
            label: "",
            notes: "",
            startsAt: 0,
            copay: 0.0,
            status: FloatPoolSummaryStatus.requested
        )
    }
}
