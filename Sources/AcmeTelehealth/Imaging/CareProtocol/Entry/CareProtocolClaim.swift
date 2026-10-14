import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol claim is in its life cycle.
    enum CareProtocolClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a care protocol claim and its current status.
    final class CareProtocolClaim {
        var code: String
        var title: String
        var weight: Double
        var source: String
        var graceDays: Int
        var status: CareProtocolClaimStatus

        init(code: String, title: String, weight: Double, source: String, graceDays: Int, status: CareProtocolClaimStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.source = source
            self.graceDays = graceDays
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

        func canMoveTo(_ next: CareProtocolClaimStatus) -> Bool {
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
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CareProtocolClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("care protocol claim") \(code)"
        }

        func projectedVolume() -> Double {
            return ((weight - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolClaim {
            return CareProtocolClaim(
                code: code,
                title: title,
                weight: weight,
                source: source,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a care protocol claim in status new.
    static func newCareProtocolClaim(_ code: String, title: String) -> CareProtocolClaim {
        return CareProtocolClaim(
            code: code,
            title: title,
            weight: 0.0,
            source: "",
            graceDays: 0,
            status: CareProtocolClaimStatus.new
        )
    }
}
