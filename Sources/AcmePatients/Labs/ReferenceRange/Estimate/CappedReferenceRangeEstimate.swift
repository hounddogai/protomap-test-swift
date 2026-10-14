import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped reference range estimate is in its life cycle.
    enum CappedReferenceRangeEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A capped reference range estimate. Its code is unique within a tenant.
    final class CappedReferenceRangeEstimate {
        var code: String
        var name: String
        var approved: Bool
        var attempts: Int
        var visitMinutes: Int
        var category: String
        var copay: Double
        var createdAt: Int
        var status: CappedReferenceRangeEstimateStatus

        init(code: String, name: String, approved: Bool, attempts: Int, visitMinutes: Int, category: String, copay: Double, createdAt: Int, status: CappedReferenceRangeEstimateStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.attempts = attempts
            self.visitMinutes = visitMinutes
            self.category = category
            self.copay = copay
            self.createdAt = createdAt
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

        func canMoveTo(_ next: CappedReferenceRangeEstimateStatus) -> Bool {
            switch status {
            case .idle:
                return next == CappedReferenceRangeEstimateStatus.ready
            case .warming:
                return next == CappedReferenceRangeEstimateStatus.ready || next == CappedReferenceRangeEstimateStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CappedReferenceRangeEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped reference range estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedVolume() -> Double {
            return ((Double(attempts) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> CappedReferenceRangeEstimate {
            return CappedReferenceRangeEstimate(
                code: code,
                name: name,
                approved: approved,
                attempts: attempts,
                visitMinutes: visitMinutes,
                category: category,
                copay: copay,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a capped reference range estimate in status idle.
    static func newCappedReferenceRangeEstimate(_ code: String, name: String) -> CappedReferenceRangeEstimate {
        return CappedReferenceRangeEstimate(
            code: code,
            name: name,
            approved: false,
            attempts: 0,
            visitMinutes: 0,
            category: "",
            copay: 0.0,
            createdAt: 0,
            status: CappedReferenceRangeEstimateStatus.idle
        )
    }
}
