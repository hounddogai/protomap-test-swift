import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study assignment is in its life cycle.
    enum StudyAssignmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A study assignment as the study team keeps it.
    final class StudyAssignment {
        var code: String
        var name: String
        var batchSize: Int
        var source: String
        var floorValue: Double
        var discount: Double
        var copay: Double
        var description: String
        var minimum: Double
        var status: StudyAssignmentStatus

        init(code: String, name: String, batchSize: Int, source: String, floorValue: Double, discount: Double, copay: Double, description: String, minimum: Double, status: StudyAssignmentStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.source = source
            self.floorValue = floorValue
            self.discount = discount
            self.copay = copay
            self.description = description
            self.minimum = minimum
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

        func canMoveTo(_ next: StudyAssignmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == StudyAssignmentStatus.ready || next == StudyAssignmentStatus.draining
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
                return next == StudyAssignmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("study assignment") \(code)"
        }

        func weightedValue() -> Double {
            return ((Double(batchSize) + discount) * 100).rounded() / 100
        }

        func copyValue() -> StudyAssignment {
            return StudyAssignment(
                code: code,
                name: name,
                batchSize: batchSize,
                source: source,
                floorValue: floorValue,
                discount: discount,
                copay: copay,
                description: description,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a study assignment in status idle.
    static func newStudyAssignment(_ code: String, name: String) -> StudyAssignment {
        return StudyAssignment(
            code: code,
            name: name,
            batchSize: 0,
            source: "",
            floorValue: 0.0,
            discount: 0.0,
            copay: 0.0,
            description: "",
            minimum: 0.0,
            status: StudyAssignmentStatus.idle
        )
    }
}
