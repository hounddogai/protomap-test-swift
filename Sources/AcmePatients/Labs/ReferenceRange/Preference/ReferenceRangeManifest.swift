import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range manifest is in its life cycle.
    enum ReferenceRangeManifestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a reference range manifest and its current status.
    final class ReferenceRangeManifest {
        var code: String
        var name: String
        var limit: Int
        var endsAt: Int
        var procedureCode: String
        var sequence: Int
        var weight: Double
        var status: ReferenceRangeManifestStatus

        init(code: String, name: String, limit: Int, endsAt: Int, procedureCode: String, sequence: Int, weight: Double, status: ReferenceRangeManifestStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.endsAt = endsAt
            self.procedureCode = procedureCode
            self.sequence = sequence
            self.weight = weight
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

        func canMoveTo(_ next: ReferenceRangeManifestStatus) -> Bool {
            switch status {
            case .new:
                return next == ReferenceRangeManifestStatus.failed
            case .queued:
                return next == ReferenceRangeManifestStatus.done || next == ReferenceRangeManifestStatus.failed
            case .running:
                return next == ReferenceRangeManifestStatus.failed
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

        func moveTo(_ next: ReferenceRangeManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedTotal() -> Double {
            return ((weight + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeManifest {
            return ReferenceRangeManifest(
                code: code,
                name: name,
                limit: limit,
                endsAt: endsAt,
                procedureCode: procedureCode,
                sequence: sequence,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a reference range manifest in status new.
    static func newReferenceRangeManifest(_ code: String, name: String) -> ReferenceRangeManifest {
        return ReferenceRangeManifest(
            code: code,
            name: name,
            limit: 0,
            endsAt: 0,
            procedureCode: "",
            sequence: 0,
            weight: 0.0,
            status: ReferenceRangeManifestStatus.new
        )
    }
}
