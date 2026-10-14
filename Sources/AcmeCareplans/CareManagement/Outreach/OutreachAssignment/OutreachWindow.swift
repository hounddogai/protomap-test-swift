import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach window is in its life cycle.
    enum OutreachWindowStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One outreach window, with what the planners need to act on it.
    final class OutreachWindow {
        var code: String
        var title: String
        var bed: String
        var weight: Double
        var facility: String
        var ceiling: Double
        var discount: Double
        var revision: Int
        var status: OutreachWindowStatus

        init(code: String, title: String, bed: String, weight: Double, facility: String, ceiling: Double, discount: Double, revision: Int, status: OutreachWindowStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.weight = weight
            self.facility = facility
            self.ceiling = ceiling
            self.discount = discount
            self.revision = revision
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

        func canMoveTo(_ next: OutreachWindowStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == OutreachWindowStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedVolume() -> Double {
            return ((discount - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachWindow {
            return OutreachWindow(
                code: code,
                title: title,
                bed: bed,
                weight: weight,
                facility: facility,
                ceiling: ceiling,
                discount: discount,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a outreach window in status requested.
    static func newOutreachWindow(_ code: String, title: String) -> OutreachWindow {
        return OutreachWindow(
            code: code,
            title: title,
            bed: "",
            weight: 0.0,
            facility: "",
            ceiling: 0.0,
            discount: 0.0,
            revision: 0,
            status: OutreachWindowStatus.requested
        )
    }
}
