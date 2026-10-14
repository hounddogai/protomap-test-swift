import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession bundle is in its life cycle.
    enum AccessionBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One accession bundle, with what the planners need to act on it.
    final class AccessionBundle {
        var code: String
        var label: String
        var ward: String
        var archived: Bool
        var bed: String
        var amount: Double
        var status: AccessionBundleStatus

        init(code: String, label: String, ward: String, archived: Bool, bed: String, amount: Double, status: AccessionBundleStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.archived = archived
            self.bed = bed
            self.amount = amount
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

        func canMoveTo(_ next: AccessionBundleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AccessionBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("accession bundle") \(code)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> AccessionBundle {
            return AccessionBundle(
                code: code,
                label: label,
                ward: ward,
                archived: archived,
                bed: bed,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a accession bundle in status idle.
    static func newAccessionBundle(_ code: String, label: String) -> AccessionBundle {
        return AccessionBundle(
            code: code,
            label: label,
            ward: "",
            archived: false,
            bed: "",
            amount: 0.0,
            status: AccessionBundleStatus.idle
        )
    }
}
