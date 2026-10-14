import AcmePlatform
import Foundation

extension Consent {
    /// Moves disclosure segments through their life cycle and keeps a journal of what it did.
    final class DisclosureSegmentManager {
        var store: any DisclosureSegmentStore
        var validator: DisclosureSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DisclosureSegmentEngine

        init(store: any DisclosureSegmentStore, validator: DisclosureSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DisclosureSegmentEngine) {
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
                throw Kit.Failure("disclosure segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DisclosureSegmentStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DisclosureSegmentStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("disclosure segment \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newDisclosureSegmentManager(_ store: any DisclosureSegmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DisclosureSegmentManager {
        return DisclosureSegmentManager(
            store: store,
            validator: defaultDisclosureSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultDisclosureSegmentEngine(flags)
        )
    }
}
