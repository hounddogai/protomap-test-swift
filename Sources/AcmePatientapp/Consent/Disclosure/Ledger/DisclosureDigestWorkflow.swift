import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure digests through their life cycle and keeps a journal of what it did.
    final class DisclosureDigestService {
        var store: any DisclosureDigestStore
        var validator: DisclosureDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DisclosureDigestEngine

        init(store: any DisclosureDigestStore, validator: DisclosureDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DisclosureDigestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosureDigestStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosureDigestStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure digest \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
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

    static func newDisclosureDigestService(_ store: any DisclosureDigestStore, clock: any Kit.Clocks.Clock) -> DisclosureDigestService {
        return DisclosureDigestService(
            store: store,
            validator: defaultDisclosureDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultDisclosureDigestEngine()
        )
    }
}
