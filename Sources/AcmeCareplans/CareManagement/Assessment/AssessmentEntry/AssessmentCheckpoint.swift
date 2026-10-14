import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment checkpoint is in its life cycle.
    enum AssessmentCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A assessment checkpoint as the assessment team keeps it.
    final class AssessmentCheckpoint {
        var code: String
        var name: String
        var createdAt: Int
        var score: Double
        var windowDays: Int
        var attributes: [String: String]
        var sequence: Int
        var bed: String
        var updatedAt: Int
        var externalRef: String
        var status: AssessmentCheckpointStatus

        init(code: String, name: String, createdAt: Int, score: Double, windowDays: Int, attributes: [String: String], sequence: Int, bed: String, updatedAt: Int, externalRef: String, status: AssessmentCheckpointStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.score = score
            self.windowDays = windowDays
            self.attributes = attributes
            self.sequence = sequence
            self.bed = bed
            self.updatedAt = updatedAt
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AssessmentCheckpointStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == AssessmentCheckpointStatus.done || next == AssessmentCheckpointStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: AssessmentCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func weightedLoad() -> Double {
            return ((Double(createdAt) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentCheckpoint {
            return AssessmentCheckpoint(
                code: code,
                name: name,
                createdAt: createdAt,
                score: score,
                windowDays: windowDays,
                attributes: attributes,
                sequence: sequence,
                bed: bed,
                updatedAt: updatedAt,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a assessment checkpoint in status new.
    static func newAssessmentCheckpoint(_ code: String, name: String) -> AssessmentCheckpoint {
        return AssessmentCheckpoint(
            code: code,
            name: name,
            createdAt: 0,
            score: 0.0,
            windowDays: 0,
            attributes: [:],
            sequence: 0,
            bed: "",
            updatedAt: 0,
            externalRef: "",
            status: AssessmentCheckpointStatus.new
        )
    }
}
