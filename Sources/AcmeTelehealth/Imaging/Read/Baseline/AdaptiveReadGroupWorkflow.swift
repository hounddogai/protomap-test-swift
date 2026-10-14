import AcmePlatform
import Foundation

extension Imaging {
    /// Moves adaptive read groups through their life cycle and keeps a journal of what it did.
    final class AdaptiveReadGroupService {
        var store: any AdaptiveReadGroupStore
        var validator: AdaptiveReadGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveReadGroupEngine

        init(store: any AdaptiveReadGroupStore, validator: AdaptiveReadGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveReadGroupEngine) {
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
                throw Kit.Failure("adaptive read group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveReadGroupStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive read group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveReadGroupStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive read group \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newAdaptiveReadGroupService(_ store: any AdaptiveReadGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveReadGroupService {
        return AdaptiveReadGroupService(
            store: store,
            validator: defaultAdaptiveReadGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveReadGroupEngine(flags)
        )
    }
}
