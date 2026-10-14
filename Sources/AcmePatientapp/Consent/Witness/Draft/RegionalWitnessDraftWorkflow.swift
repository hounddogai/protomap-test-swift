import AcmePlatform
import Foundation

extension Consent {
    /// Moves regional witness drafts through their life cycle and keeps a journal of what it did.
    final class RegionalWitnessDraftDesk {
        var store: any RegionalWitnessDraftStore
        var validator: RegionalWitnessDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalWitnessDraftEngine

        init(store: any RegionalWitnessDraftStore, validator: RegionalWitnessDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalWitnessDraftEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional witness draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalWitnessDraftStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional witness draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalWitnessDraftStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional witness draft \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newRegionalWitnessDraftDesk(_ store: any RegionalWitnessDraftStore, clock: any Kit.Clocks.Clock) -> RegionalWitnessDraftDesk {
        return RegionalWitnessDraftDesk(
            store: store,
            validator: defaultRegionalWitnessDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalWitnessDraftEngine()
        )
    }
}
