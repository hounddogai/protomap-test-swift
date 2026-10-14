import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a legacy discharge plan segment is in its life cycle.
    enum LegacyDischargePlanSegmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A legacy discharge plan segment. Its code is unique within a tenant.
    final class LegacyDischargePlanSegment {
        var code: String
        var title: String
        var externalRef: String
        var refills: Int
        var ratio: Double
        var unit: String
        var batchSize: Int
        var sequence: Int
        var status: LegacyDischargePlanSegmentStatus

        init(code: String, title: String, externalRef: String, refills: Int, ratio: Double, unit: String, batchSize: Int, sequence: Int, status: LegacyDischargePlanSegmentStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.refills = refills
            self.ratio = ratio
            self.unit = unit
            self.batchSize = batchSize
            self.sequence = sequence
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

        func canMoveTo(_ next: LegacyDischargePlanSegmentStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LegacyDischargePlanSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy discharge plan segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedTotal() -> Double {
            return (Double(refills) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> LegacyDischargePlanSegment {
            return LegacyDischargePlanSegment(
                code: code,
                title: title,
                externalRef: externalRef,
                refills: refills,
                ratio: ratio,
                unit: unit,
                batchSize: batchSize,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy discharge plan segment in status proposed.
    static func newLegacyDischargePlanSegment(_ code: String, title: String) -> LegacyDischargePlanSegment {
        return LegacyDischargePlanSegment(
            code: code,
            title: title,
            externalRef: "",
            refills: 0,
            ratio: 0.0,
            unit: "",
            batchSize: 0,
            sequence: 0,
            status: LegacyDischargePlanSegmentStatus.proposed
        )
    }
}
