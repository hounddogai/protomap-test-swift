import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual acuity plan proposal is in its life cycle.
    enum ManualAcuityPlanProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A manual acuity plan proposal. Its code is unique within a tenant.
    final class ManualAcuityPlanProposal {
        var code: String
        var name: String
        var batchSize: Int
        var locale: String
        var acuity: Int
        var country: String
        var discount: Double
        var checksum: String
        var externalRef: String
        var startsAt: Int
        var priority: Int
        var status: ManualAcuityPlanProposalStatus

        init(code: String, name: String, batchSize: Int, locale: String, acuity: Int, country: String, discount: Double, checksum: String, externalRef: String, startsAt: Int, priority: Int, status: ManualAcuityPlanProposalStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.locale = locale
            self.acuity = acuity
            self.country = country
            self.discount = discount
            self.checksum = checksum
            self.externalRef = externalRef
            self.startsAt = startsAt
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualAcuityPlanProposalStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == ManualAcuityPlanProposalStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualAcuityPlanProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual acuity plan proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netTotal() -> Double {
            return (Double(acuity) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> ManualAcuityPlanProposal {
            return ManualAcuityPlanProposal(
                code: code,
                name: name,
                batchSize: batchSize,
                locale: locale,
                acuity: acuity,
                country: country,
                discount: discount,
                checksum: checksum,
                externalRef: externalRef,
                startsAt: startsAt,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a manual acuity plan proposal in status created.
    static func newManualAcuityPlanProposal(_ code: String, name: String) -> ManualAcuityPlanProposal {
        return ManualAcuityPlanProposal(
            code: code,
            name: name,
            batchSize: 0,
            locale: "",
            acuity: 0,
            country: "",
            discount: 0.0,
            checksum: "",
            externalRef: "",
            startsAt: 0,
            priority: 0,
            status: ManualAcuityPlanProposalStatus.created
        )
    }
}
