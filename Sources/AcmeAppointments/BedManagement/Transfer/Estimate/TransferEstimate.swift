import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a transfer estimate is in its life cycle.
    enum TransferEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A transfer estimate. Its code is unique within a tenant.
    final class TransferEstimate {
        var code: String
        var label: String
        var floorValue: Double
        var ratio: Double
        var acuity: Int
        var clinicianID: String
        var locale: String
        var attributes: [String: String]
        var budget: Double
        var title: String
        var status: TransferEstimateStatus

        init(code: String, label: String, floorValue: Double, ratio: Double, acuity: Int, clinicianID: String, locale: String, attributes: [String: String], budget: Double, title: String, status: TransferEstimateStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.ratio = ratio
            self.acuity = acuity
            self.clinicianID = clinicianID
            self.locale = locale
            self.attributes = attributes
            self.budget = budget
            self.title = title
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

        func canMoveTo(_ next: TransferEstimateStatus) -> Bool {
            switch status {
            case .idle:
                return next == TransferEstimateStatus.draining || next == TransferEstimateStatus.stopped
            case .warming:
                return next == TransferEstimateStatus.draining || next == TransferEstimateStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == TransferEstimateStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TransferEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("transfer estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func projectedLoad() -> Double {
            return ((ratio - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> TransferEstimate {
            return TransferEstimate(
                code: code,
                label: label,
                floorValue: floorValue,
                ratio: ratio,
                acuity: acuity,
                clinicianID: clinicianID,
                locale: locale,
                attributes: attributes,
                budget: budget,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a transfer estimate in status idle.
    static func newTransferEstimate(_ code: String, label: String) -> TransferEstimate {
        return TransferEstimate(
            code: code,
            label: label,
            floorValue: 0.0,
            ratio: 0.0,
            acuity: 0,
            clinicianID: "",
            locale: "",
            attributes: [:],
            budget: 0.0,
            title: "",
            status: TransferEstimateStatus.idle
        )
    }
}
