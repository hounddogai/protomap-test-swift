import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy program summary is in its life cycle.
    enum LegacyProgramSummaryStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A legacy program summary. Its code is unique within a tenant.
    final class LegacyProgramSummary {
        var code: String
        var label: String
        var title: String
        var active: Bool
        var phone: String
        var visitMinutes: Int
        var unit: String
        var floorValue: Double
        var sequence: Int
        var status: LegacyProgramSummaryStatus

        init(code: String, label: String, title: String, active: Bool, phone: String, visitMinutes: Int, unit: String, floorValue: Double, sequence: Int, status: LegacyProgramSummaryStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.active = active
            self.phone = phone
            self.visitMinutes = visitMinutes
            self.unit = unit
            self.floorValue = floorValue
            self.sequence = sequence
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

        func canMoveTo(_ next: LegacyProgramSummaryStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == LegacyProgramSummaryStatus.draining
            case .draining:
                return next == LegacyProgramSummaryStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyProgramSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy program summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netLoad() -> Double {
            return (floorValue * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> LegacyProgramSummary {
            return LegacyProgramSummary(
                code: code,
                label: label,
                title: title,
                active: active,
                phone: phone,
                visitMinutes: visitMinutes,
                unit: unit,
                floorValue: floorValue,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy program summary in status idle.
    static func newLegacyProgramSummary(_ code: String, label: String) -> LegacyProgramSummary {
        return LegacyProgramSummary(
            code: code,
            label: label,
            title: "",
            active: false,
            phone: "",
            visitMinutes: 0,
            unit: "",
            floorValue: 0.0,
            sequence: 0,
            status: LegacyProgramSummaryStatus.idle
        )
    }
}
