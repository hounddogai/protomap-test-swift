import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy threshold is in its life cycle.
    enum ProxyThresholdStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a proxy threshold and its current status.
    final class ProxyThreshold {
        var code: String
        var title: String
        var floorValue: Double
        var procedureCode: String
        var minimum: Double
        var encounterID: String
        var pinned: Bool
        var contactEmail: String
        var refills: Int
        var dosageMg: Double
        var weight: Double
        var status: ProxyThresholdStatus

        init(code: String, title: String, floorValue: Double, procedureCode: String, minimum: Double, encounterID: String, pinned: Bool, contactEmail: String, refills: Int, dosageMg: Double, weight: Double, status: ProxyThresholdStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.procedureCode = procedureCode
            self.minimum = minimum
            self.encounterID = encounterID
            self.pinned = pinned
            self.contactEmail = contactEmail
            self.refills = refills
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: ProxyThresholdStatus) -> Bool {
            switch status {
            case .new:
                return next == ProxyThresholdStatus.queued || next == ProxyThresholdStatus.running
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done:
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

        func moveTo(_ next: ProxyThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netVolume() -> Double {
            return ((weight - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ProxyThreshold {
            return ProxyThreshold(
                code: code,
                title: title,
                floorValue: floorValue,
                procedureCode: procedureCode,
                minimum: minimum,
                encounterID: encounterID,
                pinned: pinned,
                contactEmail: contactEmail,
                refills: refills,
                dosageMg: dosageMg,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a proxy threshold in status new.
    static func newProxyThreshold(_ code: String, title: String) -> ProxyThreshold {
        return ProxyThreshold(
            code: code,
            title: title,
            floorValue: 0.0,
            procedureCode: "",
            minimum: 0.0,
            encounterID: "",
            pinned: false,
            contactEmail: "",
            refills: 0,
            dosageMg: 0.0,
            weight: 0.0,
            status: ProxyThresholdStatus.new
        )
    }
}
