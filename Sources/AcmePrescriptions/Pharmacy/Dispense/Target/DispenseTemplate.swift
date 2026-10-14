import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense template is in its life cycle.
    enum DispenseTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A dispense template. Its code is unique within a tenant.
    final class DispenseTemplate {
        var code: String
        var name: String
        var checksum: String
        var reviewer: String
        var ownerID: String
        var facility: String
        var retries: Int
        var batchSize: Int
        var source: String
        var status: DispenseTemplateStatus

        init(code: String, name: String, checksum: String, reviewer: String, ownerID: String, facility: String, retries: Int, batchSize: Int, source: String, status: DispenseTemplateStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.reviewer = reviewer
            self.ownerID = ownerID
            self.facility = facility
            self.retries = retries
            self.batchSize = batchSize
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispenseTemplateStatus) -> Bool {
            switch status {
            case .draft:
                return next == DispenseTemplateStatus.active
            case .pending:
                return next == DispenseTemplateStatus.active || next == DispenseTemplateStatus.closed
            case .active:
                return next == DispenseTemplateStatus.suspended
            case .suspended:
                return next == DispenseTemplateStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedLoad() -> Double {
            return ((Double(retries) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseTemplate {
            return DispenseTemplate(
                code: code,
                name: name,
                checksum: checksum,
                reviewer: reviewer,
                ownerID: ownerID,
                facility: facility,
                retries: retries,
                batchSize: batchSize,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a dispense template in status draft.
    static func newDispenseTemplate(_ code: String, name: String) -> DispenseTemplate {
        return DispenseTemplate(
            code: code,
            name: name,
            checksum: "",
            reviewer: "",
            ownerID: "",
            facility: "",
            retries: 0,
            batchSize: 0,
            source: "",
            status: DispenseTemplateStatus.draft
        )
    }
}
