import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach manifest is in its life cycle.
    enum OutreachManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A outreach manifest as the outreach team keeps it.
    final class OutreachManifest {
        var code: String
        var name: String
        var description: String
        var score: Double
        var floorValue: Double
        var status: OutreachManifestStatus

        init(code: String, name: String, description: String, score: Double, floorValue: Double, status: OutreachManifestStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.score = score
            self.floorValue = floorValue
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

        func canMoveTo(_ next: OutreachManifestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == OutreachManifestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OutreachManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func weightedValue() -> Double {
            return ((floorValue - score) * 100).rounded() / 100
        }

        func copyValue() -> OutreachManifest {
            return OutreachManifest(
                code: code,
                name: name,
                description: description,
                score: score,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a outreach manifest in status created.
    static func newOutreachManifest(_ code: String, name: String) -> OutreachManifest {
        return OutreachManifest(
            code: code,
            name: name,
            description: "",
            score: 0.0,
            floorValue: 0.0,
            status: OutreachManifestStatus.created
        )
    }
}
