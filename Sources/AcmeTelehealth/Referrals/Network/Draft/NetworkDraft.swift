import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network draft is in its life cycle.
    enum NetworkDraftStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A network draft as the network team keeps it.
    final class NetworkDraft {
        var code: String
        var name: String
        var region: String
        var batchSize: Int
        var summary: String
        var sequence: Int
        var ward: String
        var ratio: Double
        var status: NetworkDraftStatus

        init(code: String, name: String, region: String, batchSize: Int, summary: String, sequence: Int, ward: String, ratio: Double, status: NetworkDraftStatus) {
            self.code = code
            self.name = name
            self.region = region
            self.batchSize = batchSize
            self.summary = summary
            self.sequence = sequence
            self.ward = ward
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkDraftStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == NetworkDraftStatus.reopened || next == NetworkDraftStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: NetworkDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("network draft") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(sequence) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> NetworkDraft {
            return NetworkDraft(
                code: code,
                name: name,
                region: region,
                batchSize: batchSize,
                summary: summary,
                sequence: sequence,
                ward: ward,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a network draft in status open.
    static func newNetworkDraft(_ code: String, name: String) -> NetworkDraft {
        return NetworkDraft(
            code: code,
            name: name,
            region: "",
            batchSize: 0,
            summary: "",
            sequence: 0,
            ward: "",
            ratio: 0.0,
            status: NetworkDraftStatus.`open`
        )
    }
}
