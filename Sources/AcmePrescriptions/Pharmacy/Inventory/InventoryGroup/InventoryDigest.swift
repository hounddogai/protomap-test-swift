import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory digest is in its life cycle.
    enum InventoryDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a inventory digest and its current status.
    final class InventoryDigest {
        var code: String
        var title: String
        var weight: Double
        var revision: Int
        var windowDays: Int
        var currency: String
        var status: InventoryDigestStatus

        init(code: String, title: String, weight: Double, revision: Int, windowDays: Int, currency: String, status: InventoryDigestStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.revision = revision
            self.windowDays = windowDays
            self.currency = currency
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

        func canMoveTo(_ next: InventoryDigestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == InventoryDigestStatus.done || next == InventoryDigestStatus.failed
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

        func moveTo(_ next: InventoryDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netTotal() -> Double {
            return ((Double(revision) + weight) * 100).rounded() / 100
        }

        func copyValue() -> InventoryDigest {
            return InventoryDigest(
                code: code,
                title: title,
                weight: weight,
                revision: revision,
                windowDays: windowDays,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a inventory digest in status new.
    static func newInventoryDigest(_ code: String, title: String) -> InventoryDigest {
        return InventoryDigest(
            code: code,
            title: title,
            weight: 0.0,
            revision: 0,
            windowDays: 0,
            currency: "",
            status: InventoryDigestStatus.new
        )
    }
}
