import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a capped denial manifest is in its life cycle.
    enum CappedDenialManifestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A capped denial manifest. Its code is unique within a tenant.
    final class CappedDenialManifest {
        var code: String
        var label: String
        var currency: String
        var channel: String
        var summary: String
        var quantity: Int
        var category: String
        var sequence: Int
        var status: CappedDenialManifestStatus

        init(code: String, label: String, currency: String, channel: String, summary: String, quantity: Int, category: String, sequence: Int, status: CappedDenialManifestStatus) {
            self.code = code
            self.label = label
            self.currency = currency
            self.channel = channel
            self.summary = summary
            self.quantity = quantity
            self.category = category
            self.sequence = sequence
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

        func canMoveTo(_ next: CappedDenialManifestStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CappedDenialManifestStatus.done
            case .running:
                switch next {
                case .done, .failed:
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

        func moveTo(_ next: CappedDenialManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped denial manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedValue() -> Double {
            return (Double(quantity) * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> CappedDenialManifest {
            return CappedDenialManifest(
                code: code,
                label: label,
                currency: currency,
                channel: channel,
                summary: summary,
                quantity: quantity,
                category: category,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped denial manifest in status new.
    static func newCappedDenialManifest(_ code: String, label: String) -> CappedDenialManifest {
        return CappedDenialManifest(
            code: code,
            label: label,
            currency: "",
            channel: "",
            summary: "",
            quantity: 0,
            category: "",
            sequence: 0,
            status: CappedDenialManifestStatus.new
        )
    }
}
