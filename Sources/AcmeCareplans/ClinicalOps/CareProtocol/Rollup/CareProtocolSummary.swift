import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a care protocol summary is in its life cycle.
    enum CareProtocolSummaryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A care protocol summary as the care protocol team keeps it.
    final class CareProtocolSummary {
        var code: String
        var name: String
        var description: String
        var limit: Int
        var unit: String
        var country: String
        var endsAt: Int
        var externalRef: String
        var category: String
        var ownerID: String
        var source: String
        var status: CareProtocolSummaryStatus

        init(code: String, name: String, description: String, limit: Int, unit: String, country: String, endsAt: Int, externalRef: String, category: String, ownerID: String, source: String, status: CareProtocolSummaryStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.limit = limit
            self.unit = unit
            self.country = country
            self.endsAt = endsAt
            self.externalRef = externalRef
            self.category = category
            self.ownerID = ownerID
            self.source = source
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

        func canMoveTo(_ next: CareProtocolSummaryStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == CareProtocolSummaryStatus.running || next == CareProtocolSummaryStatus.failed
            case .running:
                return next == CareProtocolSummaryStatus.done
            case .done:
                return next == CareProtocolSummaryStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedValue() -> Double {
            return ((Double(limit) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolSummary {
            return CareProtocolSummary(
                code: code,
                name: name,
                description: description,
                limit: limit,
                unit: unit,
                country: country,
                endsAt: endsAt,
                externalRef: externalRef,
                category: category,
                ownerID: ownerID,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a care protocol summary in status new.
    static func newCareProtocolSummary(_ code: String, name: String) -> CareProtocolSummary {
        return CareProtocolSummary(
            code: code,
            name: name,
            description: "",
            limit: 0,
            unit: "",
            country: "",
            endsAt: 0,
            externalRef: "",
            category: "",
            ownerID: "",
            source: "",
            status: CareProtocolSummaryStatus.new
        )
    }
}
