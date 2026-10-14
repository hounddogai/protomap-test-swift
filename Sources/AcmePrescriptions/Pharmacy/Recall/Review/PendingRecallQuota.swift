import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending recall quota is in its life cycle.
    enum PendingRecallQuotaStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A pending recall quota as the recall team keeps it.
    final class PendingRecallQuota {
        var code: String
        var name: String
        var visible: Bool
        var specialty: String
        var notes: String
        var region: String
        var segment: String
        var category: String
        var score: Double
        var status: PendingRecallQuotaStatus

        init(code: String, name: String, visible: Bool, specialty: String, notes: String, region: String, segment: String, category: String, score: Double, status: PendingRecallQuotaStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.specialty = specialty
            self.notes = notes
            self.region = region
            self.segment = segment
            self.category = category
            self.score = score
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

        func canMoveTo(_ next: PendingRecallQuotaStatus) -> Bool {
            switch status {
            case .created:
                return next == PendingRecallQuotaStatus.validated
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: PendingRecallQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending recall quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending recall quota") \(code)"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> PendingRecallQuota {
            return PendingRecallQuota(
                code: code,
                name: name,
                visible: visible,
                specialty: specialty,
                notes: notes,
                region: region,
                segment: segment,
                category: category,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a pending recall quota in status created.
    static func newPendingRecallQuota(_ code: String, name: String) -> PendingRecallQuota {
        return PendingRecallQuota(
            code: code,
            name: name,
            visible: false,
            specialty: "",
            notes: "",
            region: "",
            segment: "",
            category: "",
            score: 0.0,
            status: PendingRecallQuotaStatus.created
        )
    }
}
