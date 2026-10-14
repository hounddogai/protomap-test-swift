import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual statement digest is in its life cycle.
    enum ManualStatementDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a manual statement digest and its current status.
    final class ManualStatementDigest {
        var code: String
        var name: String
        var description: String
        var summary: String
        var phone: String
        var bed: String
        var visible: Bool
        var payer: String
        var quantity: Int
        var status: ManualStatementDigestStatus

        init(code: String, name: String, description: String, summary: String, phone: String, bed: String, visible: Bool, payer: String, quantity: Int, status: ManualStatementDigestStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.summary = summary
            self.phone = phone
            self.bed = bed
            self.visible = visible
            self.payer = payer
            self.quantity = quantity
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

        func canMoveTo(_ next: ManualStatementDigestStatus) -> Bool {
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
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == ManualStatementDigestStatus.done || next == ManualStatementDigestStatus.failed
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

        func moveTo(_ next: ManualStatementDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual statement digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ManualStatementDigest {
            return ManualStatementDigest(
                code: code,
                name: name,
                description: description,
                summary: summary,
                phone: phone,
                bed: bed,
                visible: visible,
                payer: payer,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual statement digest in status new.
    static func newManualStatementDigest(_ code: String, name: String) -> ManualStatementDigest {
        return ManualStatementDigest(
            code: code,
            name: name,
            description: "",
            summary: "",
            phone: "",
            bed: "",
            visible: false,
            payer: "",
            quantity: 0,
            status: ManualStatementDigestStatus.new
        )
    }
}
