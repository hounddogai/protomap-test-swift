import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional remittance variance is in its life cycle.
    enum RegionalRemittanceVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One regional remittance variance, with what the planners need to act on it.
    final class RegionalRemittanceVariance {
        var code: String
        var name: String
        var quantity: Int
        var specialty: String
        var source: String
        var tags: [String]
        var procedureCode: String
        var refills: Int
        var floorValue: Double
        var updatedAt: Int
        var status: RegionalRemittanceVarianceStatus

        init(code: String, name: String, quantity: Int, specialty: String, source: String, tags: [String], procedureCode: String, refills: Int, floorValue: Double, updatedAt: Int, status: RegionalRemittanceVarianceStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.specialty = specialty
            self.source = source
            self.tags = tags
            self.procedureCode = procedureCode
            self.refills = refills
            self.floorValue = floorValue
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: RegionalRemittanceVarianceStatus) -> Bool {
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
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RegionalRemittanceVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional remittance variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedExposure() -> Double {
            return ((Double(quantity) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> RegionalRemittanceVariance {
            return RegionalRemittanceVariance(
                code: code,
                name: name,
                quantity: quantity,
                specialty: specialty,
                source: source,
                tags: tags,
                procedureCode: procedureCode,
                refills: refills,
                floorValue: floorValue,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a regional remittance variance in status created.
    static func newRegionalRemittanceVariance(_ code: String, name: String) -> RegionalRemittanceVariance {
        return RegionalRemittanceVariance(
            code: code,
            name: name,
            quantity: 0,
            specialty: "",
            source: "",
            tags: [],
            procedureCode: "",
            refills: 0,
            floorValue: 0.0,
            updatedAt: 0,
            status: RegionalRemittanceVarianceStatus.created
        )
    }
}
