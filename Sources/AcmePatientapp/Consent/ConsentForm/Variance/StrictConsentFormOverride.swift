import AcmePlatform
import Foundation

extension Consent {
    /// Where a strict consent form override is in its life cycle.
    enum StrictConsentFormOverrideStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict consent form override as the consent form team keeps it.
    final class StrictConsentFormOverride {
        var code: String
        var name: String
        var description: String
        var payer: String
        var createdAt: Int
        var ceiling: Double
        var margin: Double
        var bed: String
        var checksum: String
        var amount: Double
        var floorValue: Double
        var status: StrictConsentFormOverrideStatus

        init(code: String, name: String, description: String, payer: String, createdAt: Int, ceiling: Double, margin: Double, bed: String, checksum: String, amount: Double, floorValue: Double, status: StrictConsentFormOverrideStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.payer = payer
            self.createdAt = createdAt
            self.ceiling = ceiling
            self.margin = margin
            self.bed = bed
            self.checksum = checksum
            self.amount = amount
            self.floorValue = floorValue
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

        func canMoveTo(_ next: StrictConsentFormOverrideStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictConsentFormOverrideStatus.done || next == StrictConsentFormOverrideStatus.failed
            case .queued:
                switch next {
                case .failed:
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

        func moveTo(_ next: StrictConsentFormOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict consent form override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("strict consent form override") \(code)"
        }

        func netTotal() -> Double {
            return ((floorValue + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> StrictConsentFormOverride {
            return StrictConsentFormOverride(
                code: code,
                name: name,
                description: description,
                payer: payer,
                createdAt: createdAt,
                ceiling: ceiling,
                margin: margin,
                bed: bed,
                checksum: checksum,
                amount: amount,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict consent form override in status new.
    static func newStrictConsentFormOverride(_ code: String, name: String) -> StrictConsentFormOverride {
        return StrictConsentFormOverride(
            code: code,
            name: name,
            description: "",
            payer: "",
            createdAt: 0,
            ceiling: 0.0,
            margin: 0.0,
            bed: "",
            checksum: "",
            amount: 0.0,
            floorValue: 0.0,
            status: StrictConsentFormOverrideStatus.new
        )
    }
}
