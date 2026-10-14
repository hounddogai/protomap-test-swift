import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary study score is in its life cycle.
    enum PrimaryStudyScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary study score. Its code is unique within a tenant.
    final class PrimaryStudyScore {
        var code: String
        var label: String
        var visible: Bool
        var version: Int
        var discount: Double
        var ward: String
        var status: PrimaryStudyScoreStatus

        init(code: String, label: String, visible: Bool, version: Int, discount: Double, ward: String, status: PrimaryStudyScoreStatus) {
            self.code = code
            self.label = label
            self.visible = visible
            self.version = version
            self.discount = discount
            self.ward = ward
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryStudyScoreStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == PrimaryStudyScoreStatus.rejected || next == PrimaryStudyScoreStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: PrimaryStudyScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary study score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("primary study score") \(code)"
        }

        func weightedValue() -> Double {
            return (Double(version) * discount * 100).rounded() / 100
        }

        func copyValue() -> PrimaryStudyScore {
            return PrimaryStudyScore(
                code: code,
                label: label,
                visible: visible,
                version: version,
                discount: discount,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a primary study score in status proposed.
    static func newPrimaryStudyScore(_ code: String, label: String) -> PrimaryStudyScore {
        return PrimaryStudyScore(
            code: code,
            label: label,
            visible: false,
            version: 0,
            discount: 0.0,
            ward: "",
            status: PrimaryStudyScoreStatus.proposed
        )
    }
}
