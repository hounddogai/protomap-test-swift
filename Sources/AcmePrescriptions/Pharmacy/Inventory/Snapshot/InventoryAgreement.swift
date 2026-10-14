import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a inventory agreement is in its life cycle.
    enum InventoryAgreementStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One inventory agreement, with what the planners need to act on it.
    final class InventoryAgreement {
        var code: String
        var title: String
        var visitMinutes: Int
        var locale: String
        var attempts: Int
        var revision: Int
        var description: String
        var region: String
        var status: InventoryAgreementStatus

        init(code: String, title: String, visitMinutes: Int, locale: String, attempts: Int, revision: Int, description: String, region: String, status: InventoryAgreementStatus) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.locale = locale
            self.attempts = attempts
            self.revision = revision
            self.description = description
            self.region = region
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

        func canMoveTo(_ next: InventoryAgreementStatus) -> Bool {
            switch status {
            case .new:
                return next == InventoryAgreementStatus.queued || next == InventoryAgreementStatus.failed
            case .queued:
                return next == InventoryAgreementStatus.done || next == InventoryAgreementStatus.failed
            case .running:
                return next == InventoryAgreementStatus.done || next == InventoryAgreementStatus.failed
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

        func moveTo(_ next: InventoryAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("inventory agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedValue() -> Double {
            return (Double(attempts) * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> InventoryAgreement {
            return InventoryAgreement(
                code: code,
                title: title,
                visitMinutes: visitMinutes,
                locale: locale,
                attempts: attempts,
                revision: revision,
                description: description,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a inventory agreement in status new.
    static func newInventoryAgreement(_ code: String, title: String) -> InventoryAgreement {
        return InventoryAgreement(
            code: code,
            title: title,
            visitMinutes: 0,
            locale: "",
            attempts: 0,
            revision: 0,
            description: "",
            region: "",
            status: InventoryAgreementStatus.new
        )
    }
}
