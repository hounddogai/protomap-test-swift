import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation profile is in its life cycle.
    enum IsolationProfileStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A isolation profile. Its code is unique within a tenant.
    final class IsolationProfile {
        var code: String
        var name: String
        var discount: Double
        var specialty: String
        var bed: String
        var status: IsolationProfileStatus

        init(code: String, name: String, discount: Double, specialty: String, bed: String, status: IsolationProfileStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.specialty = specialty
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationProfileStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: IsolationProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return discount
        }

        func copyValue() -> IsolationProfile {
            return IsolationProfile(
                code: code,
                name: name,
                discount: discount,
                specialty: specialty,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a isolation profile in status created.
    static func newIsolationProfile(_ code: String, name: String) -> IsolationProfile {
        return IsolationProfile(
            code: code,
            name: name,
            discount: 0.0,
            specialty: "",
            bed: "",
            status: IsolationProfileStatus.created
        )
    }
}
