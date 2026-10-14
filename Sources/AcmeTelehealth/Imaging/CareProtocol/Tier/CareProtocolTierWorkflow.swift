import AcmePlatform
import Foundation

extension Imaging {
    /// Moves care protocol tiers through their life cycle and keeps a journal of what it did.
    final class CareProtocolTierService {
        var store: any CareProtocolTierStore
        var validator: CareProtocolTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareProtocolTierStore, validator: CareProtocolTierValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolTierStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolTierStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newCareProtocolTierService(_ store: any CareProtocolTierStore, clock: any Kit.Clocks.Clock) -> CareProtocolTierService {
        return CareProtocolTierService(
            store: store,
            validator: defaultCareProtocolTierValidator(),
            clock: clock,
            journal: []
        )
    }
}
