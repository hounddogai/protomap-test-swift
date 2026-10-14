import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive network request is in its life cycle.
    enum AdaptiveNetworkRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A adaptive network request as the network team keeps it.
    final class AdaptiveNetworkRequest {
        var code: String
        var name: String
        var batchSize: Int
        var contactEmail: String
        var score: Double
        var refills: Int
        var createdAt: Int
        var facility: String
        var status: AdaptiveNetworkRequestStatus

        init(code: String, name: String, batchSize: Int, contactEmail: String, score: Double, refills: Int, createdAt: Int, facility: String, status: AdaptiveNetworkRequestStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.contactEmail = contactEmail
            self.score = score
            self.refills = refills
            self.createdAt = createdAt
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveNetworkRequestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveNetworkRequestStatus.approved || next == AdaptiveNetworkRequestStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: AdaptiveNetworkRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive network request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netLoad() -> Double {
            return (Double(batchSize) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveNetworkRequest {
            return AdaptiveNetworkRequest(
                code: code,
                name: name,
                batchSize: batchSize,
                contactEmail: contactEmail,
                score: score,
                refills: refills,
                createdAt: createdAt,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a adaptive network request in status proposed.
    static func newAdaptiveNetworkRequest(_ code: String, name: String) -> AdaptiveNetworkRequest {
        return AdaptiveNetworkRequest(
            code: code,
            name: name,
            batchSize: 0,
            contactEmail: "",
            score: 0.0,
            refills: 0,
            createdAt: 0,
            facility: "",
            status: AdaptiveNetworkRequestStatus.proposed
        )
    }
}
