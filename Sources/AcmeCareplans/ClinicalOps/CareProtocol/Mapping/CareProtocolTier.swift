import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol tier is in its life cycle.
    enum CareProtocolTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A care protocol tier. Its code is unique within a tenant.
    final class CareProtocolTier {
        var code: String
        var title: String
        var notes: String
        var version: Int
        var ratio: Double
        var cost: Double
        var weight: Double
        var status: CareProtocolTierStatus

        init(code: String, title: String, notes: String, version: Int, ratio: Double, cost: Double, weight: Double, status: CareProtocolTierStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.version = version
            self.ratio = ratio
            self.cost = cost
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

        func canMoveTo(_ next: CareProtocolTierStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CareProtocolTierStatus.done || next == CareProtocolTierStatus.failed
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == CareProtocolTierStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netValue() -> Double {
            return ((weight + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolTier {
            return CareProtocolTier(
                code: code,
                title: title,
                notes: notes,
                version: version,
                ratio: ratio,
                cost: cost,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a care protocol tier in status new.
    static func newCareProtocolTier(_ code: String, title: String) -> CareProtocolTier {
        return CareProtocolTier(
            code: code,
            title: title,
            notes: "",
            version: 0,
            ratio: 0.0,
            cost: 0.0,
            weight: 0.0,
            status: CareProtocolTierStatus.new
        )
    }
}
