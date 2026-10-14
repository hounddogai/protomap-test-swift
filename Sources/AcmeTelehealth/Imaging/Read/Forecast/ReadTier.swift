import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read tier is in its life cycle.
    enum ReadTierStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A read tier. Its code is unique within a tenant.
    final class ReadTier {
        var code: String
        var label: String
        var patientRef: String
        var approved: Bool
        var floorValue: Double
        var name: String
        var retries: Int
        var maximum: Double
        var status: ReadTierStatus

        init(code: String, label: String, patientRef: String, approved: Bool, floorValue: Double, name: String, retries: Int, maximum: Double, status: ReadTierStatus) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.approved = approved
            self.floorValue = floorValue
            self.name = name
            self.retries = retries
            self.maximum = maximum
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

        func canMoveTo(_ next: ReadTierStatus) -> Bool {
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
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ReadTierStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return (Double(retries) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> ReadTier {
            return ReadTier(
                code: code,
                label: label,
                patientRef: patientRef,
                approved: approved,
                floorValue: floorValue,
                name: name,
                retries: retries,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a read tier in status created.
    static func newReadTier(_ code: String, label: String) -> ReadTier {
        return ReadTier(
            code: code,
            label: label,
            patientRef: "",
            approved: false,
            floorValue: 0.0,
            name: "",
            retries: 0,
            maximum: 0.0,
            status: ReadTierStatus.created
        )
    }
}
