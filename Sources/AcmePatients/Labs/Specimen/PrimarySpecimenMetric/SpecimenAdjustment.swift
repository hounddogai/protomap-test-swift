import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen adjustment is in its life cycle.
    enum SpecimenAdjustmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A specimen adjustment as the specimen team keeps it.
    final class SpecimenAdjustment {
        var code: String
        var label: String
        var diagnosisCode: String
        var sequence: Int
        var category: String
        var facility: String
        var amount: Double
        var channel: String
        var refills: Int
        var country: String
        var status: SpecimenAdjustmentStatus

        init(code: String, label: String, diagnosisCode: String, sequence: Int, category: String, facility: String, amount: Double, channel: String, refills: Int, country: String, status: SpecimenAdjustmentStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.sequence = sequence
            self.category = category
            self.facility = facility
            self.amount = amount
            self.channel = channel
            self.refills = refills
            self.country = country
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

        func canMoveTo(_ next: SpecimenAdjustmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SpecimenAdjustmentStatus.active || next == SpecimenAdjustmentStatus.closed
            case .active:
                return next == SpecimenAdjustmentStatus.suspended || next == SpecimenAdjustmentStatus.closed
            case .suspended:
                return next == SpecimenAdjustmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedValue() -> Double {
            return ((Double(refills) - amount) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenAdjustment {
            return SpecimenAdjustment(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                sequence: sequence,
                category: category,
                facility: facility,
                amount: amount,
                channel: channel,
                refills: refills,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a specimen adjustment in status draft.
    static func newSpecimenAdjustment(_ code: String, label: String) -> SpecimenAdjustment {
        return SpecimenAdjustment(
            code: code,
            label: label,
            diagnosisCode: "",
            sequence: 0,
            category: "",
            facility: "",
            amount: 0.0,
            channel: "",
            refills: 0,
            country: "",
            status: SpecimenAdjustmentStatus.draft
        )
    }
}
