import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement manifest is in its life cycle.
    enum StatementManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One statement manifest, with what the planners need to act on it.
    final class StatementManifest {
        var code: String
        var label: String
        var version: Int
        var cost: Double
        var visitMinutes: Int
        var quantity: Int
        var unit: String
        var phone: String
        var channel: String
        var status: StatementManifestStatus

        init(code: String, label: String, version: Int, cost: Double, visitMinutes: Int, quantity: Int, unit: String, phone: String, channel: String, status: StatementManifestStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.cost = cost
            self.visitMinutes = visitMinutes
            self.quantity = quantity
            self.unit = unit
            self.phone = phone
            self.channel = channel
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

        func canMoveTo(_ next: StatementManifestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == StatementManifestStatus.reopened || next == StatementManifestStatus.archived
            case .reopened:
                return next == StatementManifestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StatementManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedVolume() -> Double {
            return ((cost + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> StatementManifest {
            return StatementManifest(
                code: code,
                label: label,
                version: version,
                cost: cost,
                visitMinutes: visitMinutes,
                quantity: quantity,
                unit: unit,
                phone: phone,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a statement manifest in status open.
    static func newStatementManifest(_ code: String, label: String) -> StatementManifest {
        return StatementManifest(
            code: code,
            label: label,
            version: 0,
            cost: 0.0,
            visitMinutes: 0,
            quantity: 0,
            unit: "",
            phone: "",
            channel: "",
            status: StatementManifestStatus.`open`
        )
    }
}
