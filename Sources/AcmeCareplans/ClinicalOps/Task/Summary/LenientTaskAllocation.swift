import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient task allocation is in its life cycle.
    enum LenientTaskAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A lenient task allocation. Its code is unique within a tenant.
    final class LenientTaskAllocation {
        var code: String
        var title: String
        var limit: Int
        var revision: Int
        var allergy: String
        var unit: String
        var durationMinutes: Int
        var weight: Double
        var region: String
        var facility: String
        var payer: String
        var status: LenientTaskAllocationStatus

        init(code: String, title: String, limit: Int, revision: Int, allergy: String, unit: String, durationMinutes: Int, weight: Double, region: String, facility: String, payer: String, status: LenientTaskAllocationStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.revision = revision
            self.allergy = allergy
            self.unit = unit
            self.durationMinutes = durationMinutes
            self.weight = weight
            self.region = region
            self.facility = facility
            self.payer = payer
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientTaskAllocationStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LenientTaskAllocationStatus.completed
            case .inProgress:
                return next == LenientTaskAllocationStatus.completed || next == LenientTaskAllocationStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: LenientTaskAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient task allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveValue() -> Double {
            return ((Double(limit) + weight) * 100).rounded() / 100
        }

        func copyValue() -> LenientTaskAllocation {
            return LenientTaskAllocation(
                code: code,
                title: title,
                limit: limit,
                revision: revision,
                allergy: allergy,
                unit: unit,
                durationMinutes: durationMinutes,
                weight: weight,
                region: region,
                facility: facility,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a lenient task allocation in status planned.
    static func newLenientTaskAllocation(_ code: String, title: String) -> LenientTaskAllocation {
        return LenientTaskAllocation(
            code: code,
            title: title,
            limit: 0,
            revision: 0,
            allergy: "",
            unit: "",
            durationMinutes: 0,
            weight: 0.0,
            region: "",
            facility: "",
            payer: "",
            status: LenientTaskAllocationStatus.planned
        )
    }
}
