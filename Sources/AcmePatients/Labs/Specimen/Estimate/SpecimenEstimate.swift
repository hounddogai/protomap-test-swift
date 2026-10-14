import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen estimate is in its life cycle.
    enum SpecimenEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A specimen estimate as the specimen team keeps it.
    final class SpecimenEstimate {
        var code: String
        var name: String
        var segment: String
        var sequence: Int
        var minimum: Double
        var amount: Double
        var limit: Int
        var procedureCode: String
        var capacity: Int
        var patientRef: String
        var tags: [String]
        var status: SpecimenEstimateStatus

        init(code: String, name: String, segment: String, sequence: Int, minimum: Double, amount: Double, limit: Int, procedureCode: String, capacity: Int, patientRef: String, tags: [String], status: SpecimenEstimateStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.sequence = sequence
            self.minimum = minimum
            self.amount = amount
            self.limit = limit
            self.procedureCode = procedureCode
            self.capacity = capacity
            self.patientRef = patientRef
            self.tags = tags
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

        func canMoveTo(_ next: SpecimenEstimateStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == SpecimenEstimateStatus.draining || next == SpecimenEstimateStatus.stopped
            case .ready:
                return next == SpecimenEstimateStatus.stopped
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

        func moveTo(_ next: SpecimenEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("specimen estimate") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return (Double(capacity) * minimum * 100).rounded() / 100
        }

        func copyValue() -> SpecimenEstimate {
            return SpecimenEstimate(
                code: code,
                name: name,
                segment: segment,
                sequence: sequence,
                minimum: minimum,
                amount: amount,
                limit: limit,
                procedureCode: procedureCode,
                capacity: capacity,
                patientRef: patientRef,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a specimen estimate in status idle.
    static func newSpecimenEstimate(_ code: String, name: String) -> SpecimenEstimate {
        return SpecimenEstimate(
            code: code,
            name: name,
            segment: "",
            sequence: 0,
            minimum: 0.0,
            amount: 0.0,
            limit: 0,
            procedureCode: "",
            capacity: 0,
            patientRef: "",
            tags: [],
            status: SpecimenEstimateStatus.idle
        )
    }
}
