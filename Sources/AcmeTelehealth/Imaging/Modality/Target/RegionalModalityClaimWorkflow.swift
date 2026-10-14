import AcmePlatform
import Foundation

extension Imaging {
    /// Moves regional modality claims through their life cycle and keeps a journal of what it did.
    final class RegionalModalityClaimService {
        var store: any RegionalModalityClaimStore
        var validator: RegionalModalityClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalModalityClaimEngine

        init(store: any RegionalModalityClaimStore, validator: RegionalModalityClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalModalityClaimEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional modality claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalModalityClaimStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional modality claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalModalityClaimStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional modality claim \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newRegionalModalityClaimService(_ store: any RegionalModalityClaimStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalModalityClaimService {
        return RegionalModalityClaimService(
            store: store,
            validator: defaultRegionalModalityClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalModalityClaimEngine(flags)
        )
    }
}
